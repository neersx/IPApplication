using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class TextTypeBuilder : IBuilder<TextType>
    {
        public string Id { get; set; }

        public string Description { get; set; }

        public short? UsedByFlag { get; set; }

        public TextType Build()
        {
            return new TextType
            {
                Id = Id,
                TextDescription = Description ?? Fixture.String(),
                UsedByFlag = UsedByFlag
            };
        }
    }

    public class FilteredUserTextTypeBuilder : IBuilder<FilteredUserTextType>
    {
        public string TextTypeId { get; set; }

        public string TextTypeDescription { get; set; }

        public FilteredUserTextType Build()
        {
            return new FilteredUserTextType
            {
                TextDescription = TextTypeDescription ?? Fixture.String(),
                TextType = TextTypeId ?? Fixture.String()
            };
        }
    }
}