namespace Inprotech.Integration.GoogleAnalytics.Parameters
{
    public class TrackingId : Parameter
    {
        public TrackingId(string value) : base(value)
        {
        }

        public override string Name => "tid";

        public override bool IsRequired => true;
    }
}