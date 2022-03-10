using InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class FilteredEthicalWallCaseBuilder : IBuilder<FilteredEthicalWallCase>
    {
        public FilteredEthicalWallCase Build()
        {
            return new FilteredEthicalWallCase();
        }
    }
}