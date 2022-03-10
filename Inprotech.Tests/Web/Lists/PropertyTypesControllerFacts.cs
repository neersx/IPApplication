using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Lists;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class PropertyTypesControllerFacts
    {
        public PropertyTypesControllerFacts()
        {
            _propertyTypes = Substitute.For<IPropertyTypes>();
            _controller = new PropertyTypesController(_propertyTypes);
        }

        readonly IPropertyTypes _propertyTypes;
        readonly PropertyTypesController _controller;

        [Fact]
        public void ShouldForwardCorrectParametersToCaseSupportDataIfCountryIsNotSpecified()
        {
            _controller.Get("a");
            _propertyTypes.Received(1).Get("a", null);
        }

        [Fact]
        public void ShouldForwardCorrectParametersToCaseSupportDataIfCountryIsSpecified()
        {
            var countries = new[] {string.Empty};

            _controller.Get("a", countries);
            _propertyTypes.Received(1).Get("a", countries);
        }
    }
}