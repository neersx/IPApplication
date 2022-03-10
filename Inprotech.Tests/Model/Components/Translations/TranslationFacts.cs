using System.Collections.Generic;
using InprotechKaizen.Model.Components.Translations;
using Xunit;

namespace Inprotech.Tests.Model.Components.Translations
{
    public class TranslationFacts
    {
        public class Item
        {
            public int Id { get; set; }

            public string Title { get; set; }

            public string Name { get; set; }
        }

        static IDictionary<object, IDictionary<string, string>> BuildMap(int id, string title)
        {
            return new Dictionary<object, IDictionary<string, string>>
            {
                {
                    new Item {Id = id, Title = title},
                    new Dictionary<string, string>
                    {
                        {"TITLE", title}
                    }
                }
            };
        }

        [Fact]
        public void ShouldBeAbleToUseExpressionForPropertyToTranslate()
        {
            var translation = new Translation(BuildMap(1, "a"));

            var r = translation.Translate(new Item {Id = 1}, _ => _.Title);

            Assert.Equal("a", r);
        }

        [Fact]
        public void ShouldReturnDefaultValueIfEntityIsNotTranslated()
        {
            var translation = new Translation(BuildMap(1, "a"));

            var r = translation.Translate(new Item {Id = 2}, "Title");

            Assert.Null(r);
        }

        [Fact]
        public void ShouldReturnDefaultValueIfPropertyIsNotTranslated()
        {
            var translation = new Translation(BuildMap(1, "a"));

            var r = translation.Translate(new Item {Id = 2}, "Name");

            Assert.Null(r);
        }

        [Fact]
        public void ShouldReturnTranslatedText()
        {
            var translation = new Translation(BuildMap(1, "a"));

            var r = translation.Translate(new Item {Id = 1}, "Title");

            Assert.Equal("a", r);
        }

        [Fact]
        public void ShouldUseDefaultValueIfNotTranslated()
        {
            var translation = new Translation(BuildMap(1, "a"));

            var r = translation.Translate(new Item {Id = 2, Name = "a"}, "Name");

            Assert.Equal("a", r);
        }
    }
}