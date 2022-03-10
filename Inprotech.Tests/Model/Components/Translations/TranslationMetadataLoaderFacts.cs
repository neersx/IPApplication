using System.Linq;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Translations;
using Xunit;

namespace Inprotech.Tests.Model.Components.Translations
{
    public class TranslationMetadataLoaderFacts : FactBase
    {
        public class Item
        {
        }

        [Fact]
        public void ShouldLoadTypeTranslationSourceMap()
        {
            var ts = new TranslationSource
            {
                TableName = "ITEM",
                IsInUse = true
            }.In(Db);

            var loader = new TranslationMetadataLoader(Db);

            var r = loader.Load(new[] {typeof(Item)});

            Assert.Equal(ts, r[typeof(Item)].Single());
        }
    }
}