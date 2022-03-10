using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model.Components.Translations;
using InprotechKaizen.Model.Translations;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Translations
{
    public class TranslationBuilderFacts
    {
        [Table("ITEMS")]
        public class Item
        {
            [Key]
            [Column("ID")]
            public int Id { get; set; }

            [Column("TITLE")]
            public string Title { get; set; }
        }

        readonly TranslationBuilderFixture _fixture = new TranslationBuilderFixture();

        [Fact]
        public void ShouldBuildTranslation()
        {
            const string culture = "c";
            var entity = new Item {Id = 1, Title = "title"};

            _fixture.LookupCultureResolver.Resolve(culture)
                    .Returns(new LookupCulture(culture, culture));

            _fixture.TranslationMetadataLoader.Load(new[] {typeof(Item)})
                    .ReturnsForAnyArgs(new Dictionary<Type, IEnumerable<TranslationSource>>
                    {
                        {
                            typeof(Item), new[]
                            {
                                new TranslationSource
                                {
                                    TidColumn = "TITLE_TID",
                                    ShortColumn = "TITLE"
                                }
                            }
                        }
                    });

            _fixture.TidColumnLoader.Load(null, null)
                    .ReturnsForAnyArgs(new Dictionary<object, IDictionary<string, int>>
                    {
                        {
                            entity, new Dictionary<string, int>
                            {
                                {"TITLE_TID", 2}
                            }
                        }
                    });

            _fixture.TranslatedTextLoader.Load(null, null)
                    .ReturnsForAnyArgs(new Dictionary<int, string>
                    {
                        {2, "Translated"}
                    });

            var builder = _fixture.Subject.Culture(culture)
                                  .Include(new[] {entity})
                                  .Build();

            Assert.Equal("Translated", builder.Translate(entity, "Title"));
        }

        [Fact]
        public void ShouldResolveCultureIfNotSpecified()
        {
            _fixture.LookupCultureResolver.Resolve(null)
                    .ReturnsForAnyArgs(LookupCulture.TranslationNotRequired());

            _fixture.Subject.Build();

            _fixture.PreferredCultureResolver.Received(1).Resolve();
        }
    }

    internal class TranslationBuilderFixture : IFixture<ITranslationBuilder>
    {
        public TranslationBuilderFixture()
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            LookupCultureResolver = Substitute.For<ILookupCultureResolver>();
            TranslationMetadataLoader = Substitute.For<ITranslationMetadataLoader>();
            TidColumnLoader = Substitute.For<ITidColumnLoader>();
            TranslatedTextLoader = Substitute.For<ITranslatedTextLoader>();
        }

        public ITranslatedTextLoader TranslatedTextLoader { get; set; }

        public ITidColumnLoader TidColumnLoader { get; set; }

        public ITranslationMetadataLoader TranslationMetadataLoader { get; set; }

        public ILookupCultureResolver LookupCultureResolver { get; set; }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }

        public ITranslationBuilder Subject => new TranslationBuilder(
                                                                     PreferredCultureResolver,
                                                                     LookupCultureResolver,
                                                                     TranslationMetadataLoader,
                                                                     TidColumnLoader,
                                                                     TranslatedTextLoader);
    }
}