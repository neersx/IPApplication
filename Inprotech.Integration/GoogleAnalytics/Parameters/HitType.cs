namespace Inprotech.Integration.GoogleAnalytics.Parameters
{
    public class HitType : Parameter
    {
        public HitType(string value) : base(value)
        {
        }

        public override string Name => "t";

        public override bool IsRequired => true;
    }
}