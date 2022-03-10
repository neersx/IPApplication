using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Lists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class CaseCategoriesControllerFacts
    {
        public CaseCategoriesControllerFacts()
        {
            _caseCategories = Substitute.For<ICaseCategories>();
            _controller = new CaseCategoriesController(_caseCategories);
        }

        readonly ICaseCategories _caseCategories;
        readonly CaseCategoriesController _controller;

        [Fact]
        public void ShouldForwardCorrectParametersToCaseSupportData()
        {
            var countries = new string[0];
            var propertyTypes = new string[0];

            _controller.Get("a", null, countries, propertyTypes);
            _caseCategories.Received(1).Get("a", null, countries, propertyTypes);
        }
    }
}