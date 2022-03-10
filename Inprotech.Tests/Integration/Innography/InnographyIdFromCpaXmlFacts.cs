using System;
using Inprotech.Integration.Innography;
using Xunit;

namespace Inprotech.Tests.Integration.Innography
{
    public class InnographyIdFromCpaXmlFacts
    {
        const string CpaXmlWithInnographyId = @"
<Transaction xmlns='http://www.cpasoftwaresolutions.com'>
  <TransactionHeader>
    <SenderDetails>
      <Sender>Innography</Sender>
    </SenderDetails>
  </TransactionHeader>
  <TransactionBody>
    <TransactionContentDetails>
      <TransactionCode>Case Import</TransactionCode>
      <TransactionData>
        <CaseDetails>
          <SenderCaseIdentifier>I-000096327031</SenderCaseIdentifier>
        </CaseDetails>
      </TransactionData>
    </TransactionContentDetails>
  </TransactionBody>
</Transaction>
";

        const string CpaXmlWithoutInnographyId = @"
<Transaction xmlns='http://www.cpasoftwaresolutions.com'>
  <TransactionHeader>
    <SenderDetails>
      <Sender>Innography</Sender>
    </SenderDetails>
  </TransactionHeader>
  <TransactionBody>
    <TransactionContentDetails>
      <TransactionCode>Case Import</TransactionCode>
      <TransactionData>
        <CaseDetails />
      </TransactionData>
    </TransactionContentDetails>
  </TransactionBody>
</Transaction>
";

        [Fact]
        public void FindsInnographyIdFromCpaXml()
        {
            var subject = new InnographyIdFromCpaXml();

            var innorgaphyId = subject.Resolve(CpaXmlWithInnographyId);

            Assert.Equal("I-000096327031", innorgaphyId);
        }

        [Fact]
        public void ThrowsExceptionWhenInnographyIdNotFound()
        {
            Assert.Throws<InvalidOperationException>(() => { new InnographyIdFromCpaXml().Resolve(CpaXmlWithoutInnographyId); });
        }
    }
}