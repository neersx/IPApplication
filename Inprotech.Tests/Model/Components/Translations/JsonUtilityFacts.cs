using Inprotech.Infrastructure;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Xunit;

namespace Inprotech.Tests.Model.Components.Translations
{
    public class JsonUtilityFacts
    {
        static string ToJson(dynamic o)
        {
            return JObject.FromObject(o).ToString();
        }

        [Fact]
        public void FlattensHierarchy()
        {
            var input = new
            {
                z = "z",
                y = "y",
                a = "a",
                w = new
                {
                    a = "a",
                    z = "z",
                    k = new
                    {
                        a = "a",
                        b = "b",
                        w = "w",
                        j = "j",
                        z = "z"
                    },
                    i = "i"
                },
                b = "b"
            };

            var r = JsonUtility.FlattenHierarchy(ToJson(input));

            Assert.Equal("z", r["z"]);
            Assert.Equal("y", r["y"]);
            Assert.Equal("a", r["a"]);
            Assert.Equal("a", r["w.a"]);
            Assert.Equal("z", r["w.z"]);
            Assert.Equal("a", r["w.k.a"]);
            Assert.Equal("b", r["w.k.b"]);
            Assert.Equal("w", r["w.k.w"]);
            Assert.Equal("j", r["w.k.j"]);
            Assert.Equal("z", r["w.k.z"]);
            Assert.Equal("i", r["w.i"]);
        }

        [Fact]
        public void SortSublevelProperties()
        {
            var input = new
            {
                z = "z",
                y = "y",
                a = "a",
                w = new
                {
                    a = "a",
                    z = "z",
                    k = new
                    {
                        a = "a",
                        b = "b",
                        w = "w",
                        j = "j",
                        z = "z"
                    },
                    i = "i"
                },
                b = "b"
            };

            var expected = new
            {
                a = "a",
                b = "b",
                w = new
                {
                    a = "a",
                    i = "i",
                    k = new
                    {
                        a = "a",
                        b = "b",
                        j = "j",
                        w = "w",
                        z = "z"
                    },
                    z = "z"
                },
                y = "y",
                z = "z"
            };

            var r = JsonUtility.NormalizeJsonString(ToJson(input), Formatting.Indented);
            Assert.Equal(ToJson(expected), r);
        }

        [Fact]
        public void SortTopLevelProperties()
        {
            var input = new
            {
                z = "z",
                y = "y",
                a = "a",
                w = "w",
                b = "b"
            };

            var expected = new
            {
                a = "a",
                b = "b",
                w = "w",
                y = "y",
                z = "z"
            };

            var r = JsonUtility.NormalizeJsonString(ToJson(input), Formatting.Indented);
            Assert.Equal(ToJson(expected), r);
        }
    }
}