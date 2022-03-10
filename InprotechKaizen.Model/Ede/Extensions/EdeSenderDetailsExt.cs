using System.Linq;

namespace InprotechKaizen.Model.Ede.Extensions
{
    public static class EdeSenderDetailsExt
    {
        public static IQueryable<EdeSenderDetails> ImportedFromFile(this IQueryable<EdeSenderDetails> senderDetails)
        {
            return senderDetails.Where(sd => sd.TransactionHeader.BatchId >= 0);
        }
    }
}
