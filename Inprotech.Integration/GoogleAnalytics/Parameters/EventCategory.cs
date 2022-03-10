using System.Collections.Generic;

namespace Inprotech.Integration.GoogleAnalytics.Parameters
{
    public class EventCategory : Parameter
    {
        public EventCategory(string value)
            : base(value)
        {
        }

        public override string Name => "ec";

        public override List<string> SupportedHitTypes => new List<string> {HitTypes.Event};
    }
}