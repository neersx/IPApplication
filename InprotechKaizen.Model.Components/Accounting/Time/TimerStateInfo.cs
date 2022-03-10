namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class TimerStateInfo
    {
        public bool HasActiveTimer { get; set; }

        public TimeEntry BasicDetails { get; set; }

        public static TimerStateInfo StoppedTimer(TimeEntry details)
        {
            return new TimerStateInfo {BasicDetails = details, HasActiveTimer = false};
        }

        public static TimerStateInfo StartedTimer(TimeEntry details)
        {
            return new TimerStateInfo {BasicDetails = details, HasActiveTimer = true};
        }
    }
}