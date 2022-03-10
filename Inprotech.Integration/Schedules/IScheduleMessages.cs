using System.Collections.Generic;

namespace Inprotech.Integration.Schedules
{
    public interface IScheduleMessages
    {
        ScheduleMessage Resolve(int scheduleId);
        IEnumerable<ScheduleMessage> Resolve(IEnumerable<int> scheduleIds);
    }

    public class ScheduleMessage
    {
        public ScheduleMessage(string message)
        {
            Message = message;
        }

        public ScheduleMessage(string message, string urlText, string url)
        {
            Message = message;
            Link = new LinkInfo(urlText, url);
        }
        public string Message { get; set; }

        public LinkInfo Link { get; set; }

        public class LinkInfo
        {
            public LinkInfo(string text, string url)
            {
                Url = url;
                Text = text;
            }

            public string Url { get; set; }
            public string Text { get; set; }
        }
    }
}
