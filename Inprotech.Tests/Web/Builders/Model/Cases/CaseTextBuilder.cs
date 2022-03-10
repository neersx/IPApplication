using System;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseTextBuilder : IBuilder<CaseText>
    {
        public int? CaseId { get; set; }

        public string TextTypeId { get; set; }

        public string Text { get; set; }

        public short? TextNumber { get; set; }

        public string Class { get; set; }

        public int? Language { get; set; }

        public DateTime? ModifiedDate { get; set; }

        public CaseText Build()
        {
            return new CaseText(CaseId ?? Fixture.Integer(), TextTypeId ?? Fixture.String(), TextNumber ?? Fixture.Short(), Class)
            {
                Text = Text,
                ModifiedDate = ModifiedDate ?? Fixture.Today(),
                Language = Language 
            };
        }
    }
}