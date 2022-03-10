namespace Inprotech.Contracts.Messages.Security
{
    public class UserSessionInvalidatedMessage : Message
    {
        public int IdentityId { get; set; }
    }

    public class UserSessionsInvalidatedMessage : Message
    {
        public int[] IdentityIds { get; set; }
    }

    public class UserSessionStartedMessage : Message
    {
        public int IdentityId { get; set; }
    }
}