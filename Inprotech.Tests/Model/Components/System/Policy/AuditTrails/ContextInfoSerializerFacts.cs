using System;
using System.Globalization;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration.SiteControl;
using Xunit;

namespace Inprotech.Tests.Model.Components.System.Policy.AuditTrails
{
    public class ContextInfoSerializerFacts : FactBase
    {
        [Theory]
        [InlineData(45, null, null, null, null, null,"0000002D0000000000000000000000000000000000000000")]
        [InlineData(45, null, null, 2000, null, null, "0000002D0000000000000000000007D00000000000000000")]
        [InlineData(23, 1, 5, 67, 12, 1, "000000170000000100000005000000430000000C00000001")]
        public void ShouldSerializeAccordingly(int userId, int? transactionId, int? batchId, int? officeId, int? logtimeOffset, int? componentId, string expectedBitSequence)
        {
            if (logtimeOffset != null)
            {
                new SiteControl(SiteControls.LogTimeOffset) { IntegerValue = logtimeOffset }.In(Db);
            }

            if (officeId != null)
            {
                new SiteControl(SiteControls.OfficeForReplication) { IntegerValue = officeId }.In(Db);
            }

            var subject = new ContextInfoSerializer(Db);

            var result = BitConverter.ToString(subject.SerializeContextInfo(userId, transactionId, batchId, componentId)).Replace("-", string.Empty);

            Assert.Equal(expectedBitSequence, result);

            Assert.Equal(userId, Parse(result, 0));
            Assert.Equal(transactionId ?? 0, Parse(result, 8));
            Assert.Equal(batchId ?? 0, Parse(result, 16));
            Assert.Equal(officeId ?? 0, Parse(result, 24));
            Assert.Equal(logtimeOffset ?? 0, Parse(result, 32));
            Assert.Equal(componentId ?? 0, Parse(result, 40));
        }

        static int? Parse(string sequence, int start)
        {
            return int.Parse(sequence.Substring(start, 8), NumberStyles.HexNumber);
        }
    }
}