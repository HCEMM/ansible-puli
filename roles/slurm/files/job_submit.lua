function slurm_job_submit(job_desc, part_list, submit_uid)
    -- We used to have a default account for the GPU partition, 
    -- but now associations take care of limiting gpu/high mem access.
    if job_desc.partition == "gpu" and job_desc.account == nil then

        -- We are now monitoring the use of GPUs, so we need to make sure that the user is specifying the number of GPUs they want to use.
        if job_desc.gres == nil or job_desc.gres == "" then
            slurm.log_user(
                "GPU partition requires --gres=gpu:1"
            )
            return slurm.ESLURM_INVALID_GRES
        end

        -- job_desc.account = "gpu"
    end

    -- if job_desc.partition == "highmem" and job_desc.account == nil then
    --     job_desc.account = "highmem"
    -- end

        return slurm.SUCCESS
end

-- Required by Slurm, can just pass through
function slurm_job_modify(job_desc, job_ptr, part_list, modify_uid)
    return slurm.SUCCESS
end