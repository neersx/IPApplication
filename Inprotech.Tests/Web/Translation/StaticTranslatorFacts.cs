using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using Inprotech.Web.Translation;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.Web.Translation
{
    public class StaticTranslatorFacts : IDisposable
    {
        public StaticTranslatorFacts()
        {
            _tempDirectory = Path.GetRandomFileName();
            Directory.CreateDirectory(_tempDirectory);
        }

        readonly string _tempDirectory;
        
        public void Dispose()
        {
            if (Directory.Exists(_tempDirectory))
            {
                Directory.Delete(_tempDirectory, true);
            }
        }
        
        string ToJson(object d)
        {
            return JsonConvert.SerializeObject(d, Formatting.Indented);
        }

        void Save(string fileName, string content)
        {
            File.WriteAllText(Path.Combine(_tempDirectory, fileName), content);
        }

        void Delete(string fileName)
        {
            File.Delete(Path.Combine(_tempDirectory, fileName));
        }

        static bool Wait(Func<bool> action)
        {
            const int times = 10;
            const int wait = 200;

            for (var i = 0; i < times; i++)
            {
                try
                {
                    if (action()) return true;
                }
                catch
                {
                    if (i == times - 1) throw;
                }

                Thread.Sleep(wait);
            }

            return false;
        }

        [Fact]
        public void ShouldNotPickupTranslationIfFileRemoved()
        {
            var ru = ToJson(new {GoodMorning = "Доброе утро"});
            Save("translations_ru.json", ru);

            using (var translator = new StaticTranslator(_tempDirectory))
            {
                var t = translator;
                // russian translation should be there

                var passed = Wait(() => "Доброе утро" == t.Translate("GoodMorning", new List<string> {"ru"}));
                Assert.True(passed);

                // delete the file - russian translation should disappear
                Delete("translations_ru.json");

                passed = Wait(() => "GoodMorning" == t.Translate("GoodMorning", new List<string> {"ru"}));
                Assert.True(passed);
            }
        }

        [Fact]
        public void ShouldPickupModifiedContent()
        {
            using (var translator = new StaticTranslator(_tempDirectory))
            {
                var t = translator;
                var cultures = new List<string> {"en", "fr"};
                // create file and wait for FileSystem notification to be handled

                const string source = "GoodMorning"; 
                var en = ToJson(new {GoodMorning = "Good morning"});
                Save("translations_en.json", en);

                Wait(() => source != t.Translate(source, cultures));
                Assert.Equal("Good morning", t.Translate(source, cultures));

                // now overwrite the file
                en = ToJson(new {GoodMorning = "Good night"});
                Save("translations_en.json", en);

                Wait(() => !new [] {"Good morning", source}.Contains(t.Translate(source, cultures)));
                Assert.Equal("Good night", t.Translate(source, cultures));
            }
        }

        [Fact]
        public void ShouldPickupTranslationAfterInitialLoad()
        {
            using (var translator = new StaticTranslator(_tempDirectory))
            {
                // first without any .json file, translation should return original value
                var t = translator;
                var cultures = new List<string> {"en", "fr"};
                var russian = new List<string> {"ru"};

                const string source = "GoodMorning"; 
                Assert.Equal(source, t.Translate(source, cultures));

                // add russian translation, it should be picked up by translator
                var ru = ToJson(new {GoodMorning = "Доброе утро"});
                Save("translations_ru.json", ru);

                Wait(() => source != t.Translate("GoodMorning", russian));
                Assert.Equal("Доброе утро", t.Translate("GoodMorning", russian));
            }
        }

        [Fact]
        public void ShouldReturnTranslationBasedOnPriority()
        {
            var en = ToJson(new {GoodMorning = "Good morning"});
            var fr = ToJson(new {GoodMorning = "Bon matin"});

            Save("translations_en.json", en);
            Save("translations_fr.json", fr);

            using (var translator = new StaticTranslator(_tempDirectory))
            {
                // english has priority
                Assert.Equal("Good morning", translator.Translate("GoodMorning", new List<string> {"en", "fr"}));

                // french has priority
                Assert.Equal("Bon matin", translator.Translate("GoodMorning", new List<string> {"fr", "en"}));
            }
        }

        [Fact]
        public void ShouldReturnUntranslatedAsTranslationIsNotKnown()
        {
            using (var translator = new StaticTranslator(_tempDirectory))
            {
                // because this culture is not known, it should return untranslated
                Assert.Equal("GoodMorning", translator.Translate("GoodMorning", new List<string> {"ru"}));
            }
        }

        [Fact]
        public void StructuredJsonAreAccessible()
        {
            var en = ToJson(new
            {
                common = new
                {
                    error = new
                    {
                        status1 = "A communication error has occurred. Veuillez réessayer.",
                        status403 = "You do not have sufficient privileges to perform this action."
                    }
                }
            });

            var fr = ToJson(new
            {
                common = new
                {
                    error = new
                    {
                        status403 = "Vous ne disposez pas de privilèges suffisants pour effectuer cette action."
                    }
                }
            });

            Save("translations_en.json", en);
            Save("translations_fr.json", fr);

            using (var translator = new StaticTranslator(_tempDirectory))
            {
                var result = translator.Translate(@"common.error.status403", new List<string> {"fr"});

                Assert.Equal("Vous ne disposez pas de privilèges suffisants pour effectuer cette action.", result);
            }
        }

        [Fact]
        public void ShouldPickedFromDefaultLanguageIfTranslationNotAvailable()
        {
            var en = ToJson(new
            {
                common = new
                {
                    error = new
                    {
                        status403 = "You do not have sufficient privileges to perform this action."
                    }
                }
            });

            var fr = ToJson(new
            {
                common = new
                {
                    error = new
                    {
                        status404 = "Vous ne disposez pas de privilèges suffisants pour effectuer cette action."
                    }
                }
            });
            
            Save("translations_en.json", en);
            Save("translations_fr.json", fr);

            using (var translator = new StaticTranslator(_tempDirectory))
            {
                var result = translator.TranslateWithDefault(@"common.error.status403", new List<string> {"fr"});

                Assert.Equal("You do not have sufficient privileges to perform this action.", result);
            }
        }
    }
}