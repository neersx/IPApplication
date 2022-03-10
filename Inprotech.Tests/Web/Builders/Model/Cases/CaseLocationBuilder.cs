using System;
using Inprotech.Tests.Web.Builders.Model.Configuration;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseLocationBuilder : IBuilder<CaseLocation>
    {
        public Case Case { get; set; }
        public TableCode FileLocation { get; set; }
        public DateTime WhenMoved { get; set; }

        public CaseLocation Build()
        {
            return new CaseLocation(
                                    Case ?? new CaseBuilder().Build(),
                                    FileLocation ?? new TableCodeBuilder().Build(),
                                    WhenMoved);
        }
    }
}