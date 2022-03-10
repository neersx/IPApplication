using System;
using System.Linq;
using System.Threading;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport
{
    public interface ICpaXmlToEde
    {
        bool PrepareEdeBatch(string cpaxmlInput, out int batchId);

        string Submit(int batchNumber);
    }

    public class CpaXmlToEde : ICpaXmlToEde
    {
        readonly ISqlXmlBulkLoad _sqlXmlBulkLoad;
        readonly IBulkLoadProcessing _bulkLoadProcessing;
        readonly IDbContext _dbContext;

        static readonly object LockObject = new object();

        static readonly TimeSpan WaitThreshold = TimeSpan.FromSeconds(3);

        const string Schema = @"assets\schemas\ede\xsd_EDECPA-XML.xsd";

        public CpaXmlToEde(ISqlXmlBulkLoad sqlXmlBulkLoad, IBulkLoadProcessing bulkLoadProcessing, IDbContext dbContext)
        {
            _sqlXmlBulkLoad = sqlXmlBulkLoad;
            _bulkLoadProcessing = bulkLoadProcessing;
            _dbContext = dbContext;
        }

        bool TryLoadDataExclusively(string cpaXmlInput, out int batchNumber)
        {
            batchNumber = -1;

            var isLockAcquired = false;

            try
            {
                Monitor.TryEnter(LockObject, WaitThreshold, ref isLockAcquired);
                if (!isLockAcquired)
                    return false;

                var currentUser = _bulkLoadProcessing.CurrentDbContextUser();

                _bulkLoadProcessing.ClearCorruptBatch(currentUser);

                if (!_sqlXmlBulkLoad.TryExecute(Schema, cpaXmlInput, out var error))
                    throw new Exception(error);

                var bn = _bulkLoadProcessing.AcquireBatchNumber();
                if (bn == null)
                    throw new Exception("Unable to assign a batch number");

                batchNumber = bn.Value;
            }
            finally
            {
                if (isLockAcquired)
                    Monitor.Exit(LockObject);
            }
            return true;
        }

        public bool PrepareEdeBatch(string cpaXmlInput, out int id)
        {
            if (string.IsNullOrWhiteSpace(cpaXmlInput)) throw new ArgumentNullException(nameof(cpaXmlInput));

            id = -1;

            if (!TryLoadDataExclusively(cpaXmlInput, out var batchNumber))
                return false;

            _bulkLoadProcessing.ValidateBatchHeader(batchNumber);

            id = batchNumber;

            return true;
        }

        public string Submit(int batchNumber)
        {
            var edeSenderDetails = _dbContext
                            .Set<EdeSenderDetails>()
                            .Single(e => e.TransactionHeader.BatchId == batchNumber);

            _bulkLoadProcessing.SubmitToEde(edeSenderDetails.TransactionHeader.BatchId);

            return edeSenderDetails.SenderRequestIdentifier;
        }
    }
}
