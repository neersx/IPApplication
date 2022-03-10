using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Components.Translations;
using Xunit;

namespace Inprotech.Tests.Model.Components.Translations
{
    public class UtilitiesFacts
    {
        [Table("ITEMS")]
        public class Item
        {
            [Key]
            [Column("ITEM_ID")]
            public int Id { get; set; }

            [Column("ITEM_TITLE")]
            public string Title { get; set; }
        }

        public class Convention
        {
            public int Id { get; set; }

            public string Name { get; set; }
        }

        public class GetColumnName
        {
            [Fact]
            public void ByConvention()
            {
                Assert.Equal("NAME", Utilities.GetColumnName(typeof(Convention), "Name"));
            }

            [Fact]
            public void WithColumnAttribute()
            {
                Assert.Equal("ITEM_TITLE", Utilities.GetColumnName(typeof(Item), "Title"));
            }
        }

        public class GetKeyColumnName
        {
            [Fact]
            public void ByConvention()
            {
                Assert.Equal("ID", Utilities.GetKeyColumnName(typeof(Convention)));
            }

            [Fact]
            public void WithKeyAttribute()
            {
                Assert.Equal("ITEM_ID", Utilities.GetKeyColumnName(typeof(Item)));
            }
        }

        public class GetTableName
        {
            [Fact]
            public void ByConvention()
            {
                Assert.Equal("CONVENTION", Utilities.GetTableName(typeof(Convention)));
            }

            [Fact]
            public void WithTableAttribute()
            {
                Assert.Equal("ITEMS", Utilities.GetTableName(typeof(Item)));
            }
        }

        public class GetKeyProperty
        {
            [Fact]
            public void ByConvention()
            {
                Assert.Equal("Id", Utilities.GetKeyProperty(typeof(Convention)).Name);
            }

            [Fact]
            public void WithKeyAttribute()
            {
                Assert.Equal("Id", Utilities.GetKeyProperty(typeof(Item)).Name);
            }
        }

        [Fact]
        public void GetKeyValue()
        {
            Assert.Equal(1, Utilities.GetKeyValue(new Item {Id = 1}));
        }

        [Fact]
        public void GetPropertyValue()
        {
            Assert.Equal("a", Utilities.GetPropertyValue(new Item {Title = "a"}, "Title"));
        }

        [Fact]
        public void ResolvePropertyName()
        {
            Assert.Equal("Title", Utilities.ResolvePropertyName<Item>(_ => _.Title));
        }
    }
}