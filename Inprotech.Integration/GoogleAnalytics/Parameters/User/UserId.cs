namespace Inprotech.Integration.GoogleAnalytics.Parameters.User
{
    public class UserId : Parameter
    {
        public UserId(string value) : base(value)
        {
        }

        public override string Name => "uid";
    }
}