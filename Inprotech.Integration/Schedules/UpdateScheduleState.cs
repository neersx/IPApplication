using System;

namespace Inprotech.Integration.Schedules
{
    public interface IUpdateScheduleState
    {
        void For(Schedule s);
    }

    public class UpdateScheduleState : IUpdateScheduleState
    {
        readonly Func<DateTime> _today;

        public UpdateScheduleState(Func<DateTime> today)
        {
            if (today == null) throw new ArgumentNullException("today");
            _today = today;
        }

        public void For(Schedule s)
        {
            if (s.State == ScheduleState.RunNow)
            {
                s.State = ScheduleState.Purgatory;
                return;
            }

            if ((s.IsRunNow() || s.IsRunOnce()) && s.State == ScheduleState.Purgatory)
            {
                s.State = ScheduleState.Expired;
                return;
            }

            if (s.NextRun == null && s.ExpiresAfter != null)
            {
                s.State = _today().Date > s.ExpiresAfter.GetValueOrDefault().Date
                    ? ScheduleState.Expired
                    : ScheduleState.Purgatory;
                return;
            }

            s.State = ScheduleState.Active;
        }
    }
}