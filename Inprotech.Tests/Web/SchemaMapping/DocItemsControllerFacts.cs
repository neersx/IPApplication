//using Inprotech.Tests.Fakes;
//using Inprotech.Web.SchemaMapping;
//using InprotechKaizen.Model.Documents;
//using Xunit;
//
//namespace Inprotech.Tests.Web.SchemaMapping
//{
//    public class DocItemsControllerFacts: FactBase
//    {
//        const int PageSize = 2;
//        readonly DocItemsController _controller;
//        public DocItemsControllerFacts()
//        {
//            _controller = new DocItemsController(Db);
//
//            new DocItem
//            {
//                Id = 1,
//                Name = "item_c",
//                Description = "",
//            }.In(Db);
//
//            new DocItem
//            {
//                Id = 2,
//                Name = "item_b",
//                Description = "",
//            }.In(Db);
//
//            new DocItem
//            {
//                Id = 3,
//                Name = "item_a",
//                Description = "",
//
//            }.In(Db);
//
//            new DocItem
//            {
//                Id = 4,
//                Name = "hidden",
//                Description = "",
//            }.In(Db);
//        }
//
//        [Fact]
//        public void ShouldReturnPageCount()
//        {
//            var results = _controller.Get("item", 1, PageSize, true);
//
//            Assert.Equal(2, results.PageCount);
//        }
//
//        [Fact]
//        public void ShouldOrderByName()
//        {
//            var results = _controller.Get("item", 1, PageSize);
//
//            Assert.Equal("item_a", results.DocItems[0].Name);
//            Assert.Equal("item_b", results.DocItems[1].Name);
//        }
//
//        [Fact]
//        public void ShouldReturnDifferentPage()
//        {
//            var results = _controller.Get("item", 2, PageSize);
//
//            Assert.Equal("item_c", results.DocItems[0].Name);
//        }
//
//        [Fact]
//        public void ShouldReturnEmptyResultSetIfItemNotFound()
//        {
//            var results = _controller.Get("not_existing", 0, PageSize);
//
//            Assert.Equal(0, results.DocItems.Length);
//        }
//    }
//}

