using System;
using Inprotech.Infrastructure.Formatting;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Formatting
{
    public class RoundedTimeSpanConverterFacts
    {
        [Fact]
        public void JsonSerializationForTimeSpan()
        {
            var timeSpan = TimeSpan.FromMilliseconds(100);
            var result = JsonConvert.SerializeObject(timeSpan, Newtonsoft.Json.Formatting.Indented, new RoundedTimeSpanConverter());
            Assert.Equal("\"00:00:00\"", result);

            timeSpan += TimeSpan.FromSeconds(20);
            result = JsonConvert.SerializeObject(timeSpan, Newtonsoft.Json.Formatting.Indented, new RoundedTimeSpanConverter());
            Assert.Equal("\"00:00:20\"", result);

            timeSpan += TimeSpan.FromMinutes(30);
            result = JsonConvert.SerializeObject(timeSpan, Newtonsoft.Json.Formatting.Indented, new RoundedTimeSpanConverter());
            Assert.Equal("\"00:30:20\"", result);

            timeSpan += TimeSpan.FromHours(12);
            result = JsonConvert.SerializeObject(timeSpan, Newtonsoft.Json.Formatting.Indented, new RoundedTimeSpanConverter());
            Assert.Equal("\"12:30:20\"", result);

            timeSpan += TimeSpan.FromDays(3);
            result = JsonConvert.SerializeObject(timeSpan, Newtonsoft.Json.Formatting.Indented, new RoundedTimeSpanConverter());
            Assert.Equal("\"3.12:30:20\"", result);
        }
    }
}