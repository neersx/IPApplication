using System;

namespace Inprotech.Contracts.Messages.Security
{
    public class UserAccountLockedMessage : Message
    {
        public int IdentityId { get; set; }

        public string DisplayName { get; set; }

        public string Username { get; set; }

        public string UserEmail { get; set; }

        public DateTime LockedUtc { get; set; }

        public DateTime LockedLocal { get; set; }
    }
}