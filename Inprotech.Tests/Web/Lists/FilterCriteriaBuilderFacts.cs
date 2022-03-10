using System.Xml.XPath;
using Inprotech.Web.Lists;
using Xunit;

namespace Inprotech.Tests.Web.Lists
{
    public class FilterCriteriaBuilderFacts
    {
        public FilterCriteriaBuilderFacts()
        {
            _builder = new FilterCriteriaBuilder().WithStoredProcedureName("sproc");
        }

        readonly FilterCriteriaBuilder _builder;

        [Fact]
        public void ShouldBuildFilterCriteriaGroup()
        {
            _builder.WithGroup();
            var criteria = _builder.Build();

            Assert.NotNull(criteria.XPathSelectElement("/Filtering/sproc/FilterCriteriaGroup/FilterCriteria/PickListSearch"));
        }

        [Fact]
        public void ShouldBuildIfIsCurrent()
        {
            _builder.IsCurrent = true;
            var criteria = _builder.Build();

            Assert.Equal(1, (int) criteria.XPathSelectElement("/Filtering/sproc/FilterCriteria/IsCurrent"));
        }

        [Fact]
        public void ShouldBuildIfIsStaff()
        {
            _builder.IsStaff = true;
            var criteria = _builder.Build();

            Assert.Equal(1, (int) criteria.XPathSelectElement("/Filtering/sproc/FilterCriteria/EntityFlags/IsStaff"));
        }

        [Fact]
        public void ShouldBuildNameType()
        {
            _builder.WithNameType("a");
            var criteria = _builder.Build();

            Assert.Equal("a", (string) criteria.XPathSelectElement("/Filtering/sproc/FilterCriteria/SuitableForNameTypeKey"));
        }

        [Fact]
        public void ShouldBuildSearch()
        {
            _builder.WithSearch("a");
            var criteria = _builder.Build();

            Assert.Equal("a", (string) criteria.XPathSelectElement("/Filtering/sproc/FilterCriteria/PickListSearch"));
        }

        [Fact]
        public void ShouldBuildStoredProcedureName()
        {
            var criteria = _builder.Build();

            Assert.NotNull(criteria.XPathSelectElement("/Filtering/sproc"));
        }
    }
}