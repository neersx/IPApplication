using InprotechKaizen.Model.Configuration.Screens;

namespace Inprotech.Tests.Web.Builders.Model.Configuration.Screens
{
    public class ElementControlBuilder : IBuilder<ElementControl>
    {
        public string ElementName { get; set; }
        public string FullLabel { get; set; }
        public bool? IsHidden { get; set; }
        public string ShortLabel { get; set; }

        public ElementControl Build()
        {
            return new ElementControl(
                                      ElementName ?? Fixture.String("ElementName"),
                                      FullLabel ?? Fixture.String("FullLabel"),
                                      ShortLabel ?? Fixture.String("ShortLabel"),
                                      IsHidden ?? false);
        }
    }
}