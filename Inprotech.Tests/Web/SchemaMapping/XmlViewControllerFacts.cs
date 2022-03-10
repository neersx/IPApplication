using Inprotech.Tests.Fakes;
using Inprotech.Web.SchemaMapping;
using Xunit;

namespace Inprotech.Tests.Web.SchemaMapping
{
    public class XmlViewControllerFacts : FactBase
    {
        public XmlViewControllerFacts()
        {
            _controller = new XmlViewController(Db);
        }

        readonly XmlViewController _controller;

        [Fact]
        public void ShouldReturnMappingName()
        {
            new InprotechKaizen.Model.SchemaMappings.SchemaMapping
            {
                Id = 1,
                Name = "mapping"
            }.In(Db);

            var result = _controller.Get(1);

            Assert.Equal("mapping", result.Name);
        }
    }
}