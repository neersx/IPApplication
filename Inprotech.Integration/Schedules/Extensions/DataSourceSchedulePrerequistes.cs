namespace Inprotech.Integration.Schedules.Extensions
{
    public interface IDataSourceSchedulePrerequisites
    {
        bool Validate(out string unmetRequirement);
    }
}
