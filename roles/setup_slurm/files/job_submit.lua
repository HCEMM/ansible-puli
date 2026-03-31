function slurm_job_submit(job_desc, part_list, submit_uid)
    if job_desc.partition == "gpu" and job_desc.account == nil then
        job_desc.account = "gpu"
    end

    if job_desc.partition == "highmem" and job_desc.account == nil then
        job_desc.account = "highmem"
    end

    return slurm.SUCCESS
end

-- Required by Slurm, can just pass through
function slurm_job_modify(job_desc, job_ptr, part_list, modify_uid)
    return slurm.SUCCESS
end