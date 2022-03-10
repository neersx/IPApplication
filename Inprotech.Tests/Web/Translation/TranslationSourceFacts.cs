using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Translation;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Translation
{
    public class TranslationSourceFacts
    {
        public class FetchMethod
        {
            [Fact]
            public async Task ReturnMergedRequestedTranslations()
            {
                var t = new TranslatableItem
                {
                    ResourceKey = "abc"
                };

                var f = new TranslationSourceFixture()
                    .WithDefault(t);

                f.ResourceFile.Exists(Arg.Any<string>()).Returns(true); // specific translation files exists.
                f.ResourceFile.ReadAsync(Arg.Any<string>())
                 .Returns(
                          JObject.FromObject(
                                             new {abc = "translated text"}
                                            ).ToString()
                         );

                var r = (await f.Subject.Fetch(Fixture.String())).ToArray();

                Assert.Contains(t, r);
                Assert.Equal("translated text", t.Translated);
            }

            [Fact]
            public async Task ReturnsDefaultTranslations()
            {
                var t1 = new TranslatableItem();
                var t2 = new TranslatableItem();

                var f = new TranslationSourceFixture()
                    .WithDefault(t1, t2);

                f.ResourceFile.Exists(Arg.Any<string>()).Returns(false); // specific translation files do not exists.

                var r = (await f.Subject.Fetch(Fixture.String())).ToArray();

                Assert.Contains(t1, r);

                Assert.Contains(t2, r);

                f.ResourceFile.DidNotReceiveWithAnyArgs().ReadAsync(null).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class SaveMethod
        {
            [Fact]
            public async Task CallsToApplyDelta()
            {
                var changes = new ScreenLabelChanges
                {
                    LanguageCode = "tokipona",
                    Translations = new[]
                    {
                        new ChangedTranslation
                        {
                            Key = "condor-z",
                            Value = "z"
                        }
                    }
                };

                var f = new TranslationSourceFixture();

                await f.Subject.Save(changes);

                f.DeltaPersister.Received(1)
                 .ApplyDelta(Arg.Any<string>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task CallstoUpdateDelta()
            {
                var changes = new ScreenLabelChanges
                {
                    LanguageCode = "tokipona",
                    Translations = new[]
                    {
                        new ChangedTranslation
                        {
                            Key = "condor-z",
                            Value = "z"
                        }
                    }
                };

                var f = new TranslationSourceFixture();

                await f.Subject.Save(changes);

                f.DeltaPersister.Received(1)
                 .UpdateDeltaForChanges(Arg.Any<Dictionary<string, string>>(), Arg.Any<ChangedTranslation[]>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task IgnoreNonCondorTranslations()
            {
                var changes = new ScreenLabelChanges
                {
                    Translations = new[]
                    {
                        new ChangedTranslation
                        {
                            Key = "classic-blah"
                        }
                    }
                };

                var f = new TranslationSourceFixture();

                await f.Subject.Save(changes);

                // ReSharper disable once UnusedVariable
                var unused = f.ResourceFile.DidNotReceive().BasePath;
            }
        }

        public class TranslationSourceFixture : IFixture<ITranslationSource>
        {
            public TranslationSourceFixture()
            {
                ResourceFile = Substitute.For<IResourceFile>();

                DefaultResourceExtractor = Substitute.For<IDefaultResourceExtractor>();

                DeltaPersister = Substitute.For<IDeltaPersister>();

                Subject = new TranslationSource(DefaultResourceExtractor, ResourceFile, DeltaPreserverFactory);
            }

            public IDefaultResourceExtractor DefaultResourceExtractor { get; set; }

            public IResourceFile ResourceFile { get; set; }

            public IDeltaPersister DeltaPersister { get; set; }

            public ITranslationSource Subject { get; }

            IDeltaPersister DeltaPreserverFactory(string s)
            {
                return DeltaPersister;
            }

            public TranslationSourceFixture WithDefault(params TranslatableItem[] items)
            {
                DefaultResourceExtractor.Extract().Returns(items ?? new TranslatableItem[0]);
                return this;
            }
        }
    }
}