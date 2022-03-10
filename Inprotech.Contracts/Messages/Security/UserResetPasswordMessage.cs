namespace Inprotech.Contracts.Messages.Security
{
    public class UserResetPasswordMessage : Message
    {
        public int IdentityId { get; set; }

        public string Username { get; set; }

        public string UserEmail { get; set; }

        public string EmailBody { get; set; }

        public string UserResetPassword { get; set; }
    }
}