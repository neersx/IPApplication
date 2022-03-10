namespace Inprotech.Integration.GoogleAnalytics.Parameters
{
    public class ProtocolVersion : Parameter
    {
        public ProtocolVersion(string value) : base(value)
        {
        }

        public override string Name => "v";

        public override bool IsRequired => true;
    }
}