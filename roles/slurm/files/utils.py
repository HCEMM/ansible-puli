import pandas as pd
import os

script_dir = os.path.dirname(os.path.realpath(__file__))

def write_slurm_conf_files(excel_file=f'{script_dir}/slurm_conf.xlsx', out_dir=f'{script_dir}/../templates'):
    print(f"Writing to {os.path.abspath(out_dir)}")
    xls = pd.ExcelFile(excel_file)
    os.makedirs(out_dir, exist_ok=True)
    for sheet in xls.sheet_names:
        if sheet == 'code' or sheet.startswith('x '):
            print(f"Skipping {sheet}")
            continue
        df = pd.read_excel(xls, sheet)
        with open(f"{out_dir}/{sheet}.j2", 'w') as f:
            for index, row in df.iterrows():
                if not pd.isna(row['Value']):
                    val=f.write(f"{row['Parameter']}={row['Value']}\n")
        print(f"Written {sheet}")
    xls.close()


def excel_to_markdown(excel_file, sheet_name=None):
    if sheet_name:
        df = pd.read_excel(excel_file, sheet_name)
    else:
        df = pd.read_excel(excel_file)
    print(df.to_markdown())


if __name__ == "__main__":
    write_slurm_conf_files()
