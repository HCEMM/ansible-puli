#!/opt/ohpc/pub/apps/spack/local/linux-rocky9-zen3/gcc-11.5.0/miniconda3-24.3.0-yan4dukumomld4pqervri6iyyotx3ftw/bin/python

import pandas as pd
from subprocess import check_output
from io import StringIO
from termcolor import colored
import json
from glob import glob
import time
from tqdm import tqdm
import os


pd.options.mode.copy_on_write = True


limit_cols = [              # columns to consider for limits
    "Low limit (warning)", "Low limit (serious)", "Low limit (critical)", "High limit (warning)", 
    "High limit (serious)", "High limit (critical)"]


def get_nodes():
    bash_command = "wwctl node list"
    data = check_output(bash_command, shell=True).decode()
    data = [line.split() for line in data.split("\n")][1:-1]
    return pd.DataFrame(data, columns=['NODE NAME', 'PROFILES', 'NETWORK'])["NODE NAME"].tolist()


def get_sensor_data(node: str) -> str:
    """
    Get sensor data for a node
    :param node: str, name of the node (case sensitive!)
    """
    bash_command = f"wwctl node sensors -F {node}"
    print("Getting sensor data for node:", node)
    return check_output(bash_command, shell=True).decode()


def parse_sensor_data(data: str) -> pd.DataFrame:
    """
    Data comes in the form of:
    scc-cpu01-1G:
    UID                      | 0x00              | ok
    SysHealth_Stat           | 0x00              | ok
    01-Inlet Ambient         | 20 degrees C      | ok
    02-CPU 1                 | 40 degrees C      | ok
    03-CPU 2                 | 40 degrees C      | ok
    """
    data = '\n'.join(data.split('\n')[1:-1])
    columns = [
        "Component", "Value", "Units", "Status", "Low limit (warning)", "Low limit (serious)", "Low limit (critical)", 
        "High limit (warning)", "High limit (serious)", "High limit (critical)"]
    data = pd.read_csv(StringIO(data), sep="|", names=columns)
    for col in data.columns:
        data[col] = data[col].str.strip()
    data = data.replace("na", pd.NA).replace("", pd.NA)
    return data
    

def filter_data_to_assess(data: pd.DataFrame) -> pd.DataFrame:
    """
    Filter data to only include sensors with values (both in limit columns and "Value" column)
    :param data: dict {node: pd.DataFrame} with sensor data
    """
    return data[(data["Value"].notnull()) & (data["Value"] != "0x0")]


def format_data_to_assess(data: pd.DataFrame) -> pd.DataFrame:
    """
    For columns "Value" and limit columns, replace <class 'pandas._libs.missing.NAType'> with NaN and convert to float
    :param data: dict {node: pd.DataFrame} with sensor data
    """
    for col in ["Value"] + limit_cols:
        data[col] = pd.to_numeric(data[col], errors="coerce")
    return data


def colorize_status(line: pd.Series) -> str:
    """
    Map status to color.
    """
    level_to_color = {
        "critical": "magenta",
        "serious": "red",
        "warning": "yellow"
    }
    if type(line["Value"]) != float:
        for level, color in level_to_color.items():
            if type(line[f"High limit ({level})"]) != float and line[f"High limit ({level})"] != 0.0:
                if line["Value"] > line[f"High limit ({level})"]:
                    return colored(line["Value"], color)
            if type([f"Low limit ({level})"]) != float and line[f"Low limit ({level})"] != 0.0:
                if line["Value"] < line[f"Low limit ({level})"]:
                    return colored(line["Value"], color)
    return colored(line["Value"], "green")


class SystemHealth:
    def __init__(self, out_dir="/vat/log/root/node_health", filename=None, spike_threshold=0.2, variability_factor=3.0, verbose=False):
        self.nodes = get_nodes()
        self.out_dir = out_dir
        self.spike_threshold = spike_threshold
        self.variability_factor = variability_factor
        self.verbose = verbose
        if not os.path.exists(out_dir):
            os.makedirs(out_dir)
        self.all_data = self.read_data_from_file(filename) if filename else {node: parse_sensor_data(get_sensor_data(node)) for node in self.nodes}
        self.data_to_assess = {node: format_data_to_assess(filter_data_to_assess(self.all_data[node])) for node in self.nodes}
        self.is_healthy = self.check_health()


    def check_health(self):
        """
        Filter the data to only include rows that should be assessed and check if all report "ok" for status. 
        """
        return all([data["Status"].str.contains("ok").all() for data in self.data_to_assess.values()])
    
    def print_health(self, verbose=False):
        """
        Print the health of the system
        """
        print("System is healthy!" if self.is_healthy else "System is not healthy!")
        if self.is_healthy and not self.verbose:
            return
        for node, node_data in self.data_to_assess.items():
            for i in range(len(node_data)):
                if node_data.iloc[i]["Status"] != "ok" or self.verbose:
                    print(f"Node: {node}")
                    print(f"Component: {node_data.iloc[i]['Component']}")
                    print(f'{colorize_status(node_data.iloc[i])} ({node_data.iloc[i]["Units"]})')

    def save_data_to_file(self, filename):
        """
        Saves data as JSON, in the form of: {node: {index: {column: value}}}
        :param filename: str, name of the file to save data to. If not ending with .json, exit.
        """
        if not filename.endswith("json"):
            exit("Filename must end with .json")
        data = {node: self.all_data[node].to_dict(orient="index") for node in self.nodes}
        with open(filename, 'w') as h:
            json.dump(data, h)

    def save_report(self):
        """
        Save a report of the system health, with current time.
        :param out_dir: str, directory to save the report to
        """
        self.save_data_to_file(f"{self.out_dir}/sensors_{time.strftime('%Y-%m-%d_%H:%M:%S')}.json")

    def read_data_from_file(self, filename):
        """
        Read data from a JSON file, in the form of: {node: {index: {column: value}}}
        :param filename: str, name of the file to read data from. If not ending with .json, exit.
        """
        if not filename.endswith("json"):
            exit("Filename must end with .json")
        with open(filename, 'r') as h:
            data = json.load(h)
        return {node: pd.DataFrame.from_dict(node_data, orient="index") for node, node_data in data.items()}

    def detect_spikes(self, logs_dir="/var/log/root/node_health", threshold=0.2, variability_factor=1.0):
        """
        Detects a spike comparing current with previous reports and reports on it.
        :param logs_dir: str, directory to read logs from
        :param threshold: float, threshold for spike detection

        """
        reports = glob(logs_dir + "/*.json")
        if not reports:
            print("No reports found!")
            return
        previous_data = {node: [] for node in self.nodes}
        for report in reports:
            report_data = self.read_data_from_file(report)
            report_data = {node: format_data_to_assess(filter_data_to_assess(report_data[node])) for node in self.nodes}
            for node in self.nodes:
                if node not in report_data.keys():
                    report_data[node] = []
                previous_data[node].append(report_data[node])
        h1 = open(f"{self.out_dir}/spikes.log", 'a')
        h2 = open(f"{self.out_dir}/critical_events.log", 'a')
        for node in self.nodes:
            node_data = self.data_to_assess[node]
            grouped_dfs = pd.concat(previous_data[node]).groupby("Component")       # join all logs for that node, and group the values for each component
            mean_value = grouped_dfs["Value"].mean()                                # get the average values for each component
            std_value = grouped_dfs["Value"].std()                                  # get the standard deviation for each component
            fluctuation = (node_data.set_index("Component")["Value"] - mean_value) / (std_value * variability_factor)
            spikes = fluctuation[abs(fluctuation) > threshold]
            critical_events = node_data[node_data["Value"] == "disabled"]
            for i in range(len(spikes)):
                spike_text = (
                    f"Node: {node}, Component: {spikes.index[i]}; Change: {'+' if spikes.iloc[i] > 0 else ''}"
                    f"{round(spikes.iloc[i] / mean_value.iloc[i] * 100, 2)} %; AVG: {mean_value.iloc[i]}, STD: {std_value.iloc[i]}")
                print(f"Spike detected! {spike_text}")
                h1.write(f"[{time.strftime('%Y-%m-%d_%H:%M:%S')}] {spike_text}\n")
            for i in range(len(critical_events)):
                critical_text = f"Node: {node}, Component: {critical_events.iloc[i]['Component']}; Status: {critical_events.iloc[i]['Status']}"
                print(f"Critical event detected! {critical_text}")
                h2.write(f"[{time.strftime('%Y-%m-%d_%H:%M:%S')}] {critical_text}\n")
        h1.close()
        h2.close()
    

if __name__ == "__main__":
    print(f"NODE SENSOR ASSESSMENT: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    THRESHOLD = 0.2
    VARIABILITY_FACTOR = 3.0
    OUT_DIR = "/var/log/root/node_health"
    #VERBOSE = True

    system_health = SystemHealth(
        out_dir=OUT_DIR, 
        spike_threshold=THRESHOLD,
        variability_factor=VARIABILITY_FACTOR
        #verbose=VERBOSE,
        #filename="test.json"
    )
    system_health.print_health()
    system_health.save_report()
    system_health.detect_spikes()

