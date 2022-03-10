using System;

namespace Inprotech.Integration.Schedules
{
    public class CancellationInfo
    {
        public Guid Token { get; set; }

        public DateTime CancelledOn { get; set; }

        public int ByUserId { get; set; }

        public string ByUserName { get; set; }

        public CancellationInfo(Guid cancellationToken)
        {
            Token = cancellationToken;
        }
    }
}
