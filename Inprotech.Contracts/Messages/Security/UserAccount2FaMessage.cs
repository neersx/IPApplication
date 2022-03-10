namespace Inprotech.Contracts.Messages.Security
{
    public class UserAccount2FaMessage : Message
    {
        public int IdentityId { get; set; }

        public string DisplayName { get; set; }

        public string Username { get; set; }

        public string UserEmail { get; set; }

        public string AuthenticationCode { get; set; }
    }
}