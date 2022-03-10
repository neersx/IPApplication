using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.Lists;
using Inprotech.Web.Search.CaseSupportData;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class OfficesControllerFacts
    {
        public OfficesControllerFacts()
        {
            var offices = Substitute.For<IOffices>();
            offices.Get().Returns(
                                  new Dictionary<string, string>
                                  {
                                      {"1", "abc"},
                                      {"2", "def"}
                                  }.Select(a => a));

            _controller = new OfficesController(offices);
        }

        readonly OfficesController _controller;

        [Fact]
        public void ShouldGetAllOffices()
        {
            var r = _controller.Get(string.Empty);

            Assert.Equal(2, r.Length);
        }

        [Fact]
        public void ShouldReturnNothingIfNoMatchingRecordsFound()
        {
            var r = _controller.Get("abcd");

            Assert.Equal(0, r.Length);
        }

        [Fact]
        public void ShouldReturnOfficesByCaseInsensitiveSearch()
        {
            var r = _controller.Get("Ab");

            Assert.Equal(1, r.Length);
            Assert.Equal("1", r[0].Key);
            Assert.Equal("abc", r[0].Description);
        }
    }
}