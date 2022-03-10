using System;
using System.Globalization;
using Inprotech.Integration.Innography.PrivatePair;
using Xunit;

namespace Inprotech.Tests.Integration.Innography.PrivatePair
{
    public class MessageFacts
    {
        [Theory]
        [InlineData("2019-08-27", null, "2019-08-27 00:00:00.000000")]
        [InlineData("2019-08-27", "2019-08-27 01:40:57", "2019-08-27 01:40:57.000000")]
        [InlineData("2019-08-27", "2019-08-27 01:40:57:604368", "2019-08-27 01:40:57.604368")]
        [InlineData("2019-08-27", "2019-08-27 01:40:57.604368", "2019-08-27 01:40:57.604368")]
        public void ShouldParseEventTimeStampAccordingly(string eventDateInput, string eventTimeStampInput, string expectedOutput)
        {
            var message = new Message
            {
                Meta = new Meta
                {
                    EventDate = eventDateInput,
                    EventTimeStamp = eventTimeStampInput
                }
            };

            var expected = DateTime.ParseExact(expectedOutput, "yyyy-MM-dd HH:mm:ss.ffffff", CultureInfo.InvariantCulture);

            Assert.Equal(expected, message.Meta.EventDateParsed);
        }
    }
}