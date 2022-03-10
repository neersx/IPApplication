using Inprotech.Tests.Web.Builders;
using InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders
{
    public class GoodsServicesBuilder : IBuilder<GoodsServices>
    {
        public GoodsServices Build()
        {
            return new GoodsServices
            {
                Class = Fixture.String(),
                FirstUsedDate = Fixture.Today().ToString("yyyyMMdd"),
                FirstUsedDateInCommerce = Fixture.Today().ToString("yyyyMMdd"),
                Text = Fixture.String()
            };
        }
    }
}