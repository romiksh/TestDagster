from dagster import asset, job, op, Definitions, ScheduleDefinition

# --- Assets
@asset
def raw_numbers():
    """Return a list of numbers"""
    return [1, 2, 3, 4, 5]

@asset
def sum_numbers(raw_numbers):
    """Compute the sum of the numbers"""
    return sum(raw_numbers)

# --- Classic ops/jobs (optional) ---
@op
def print_sum(sum_numbers):
    print(f"Sum of numbers: {sum_numbers}")

@job
def number_job():
    print_sum()  # will call print_sum(sum_numbers)

# --- Scheduling example ---
my_daily_schedule = ScheduleDefinition(
    job=number_job,
    cron_schedule="0 9 * * *",  # run every day at 9:00 AM
)

# --- Definitions object ties everything together ---
defs = Definitions(
    assets=[raw_numbers, sum_numbers],
    jobs=[number_job],
    schedules=[my_daily_schedule],
)

if __name__ == "__main__":
    # You can run your job manually with:
    result = number_job.execute_in_process()
    assert result.success