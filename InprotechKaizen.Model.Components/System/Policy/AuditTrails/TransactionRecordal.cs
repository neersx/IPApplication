using System;
using System.Linq;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.System.Policy.AuditTrails
{
    public class TransactionRecordal : ITransactionRecordal
    {
        readonly IContextInfo _contextInfo;
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _systemClock;
        readonly IComponentResolver _componentResolver;

        public TransactionRecordal(
            IDbContext dbContext,
            ISecurityContext securityContext,
            IContextInfo contextInfo,
            Func<DateTime> systemClock,
            IComponentResolver componentResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _contextInfo = contextInfo;
            _systemClock = systemClock;
            _componentResolver = componentResolver;
        }

        public int RecordTransactionForCase(int caseId, CaseTransactionMessageIdentifier transactionMessage, int? reasonNo = null, string component = null)
        {
            int? componentId = null;
            if (!string.IsNullOrWhiteSpace(component))
            {
                componentId = _componentResolver.Resolve(component);
            }

            return RecordTransaction(new TransactionInfo(caseId, _systemClock(), (int) transactionMessage, reasonNo), componentId: componentId);
        }

        public int RecordTransactionFor(Case @case, CaseTransactionMessageIdentifier transactionMessage, int? reasonNo = null, int? componentId = null)
        {
            return RecordTransaction(new TransactionInfo(@case, _systemClock(), (int) transactionMessage, reasonNo), componentId: componentId);
        }

        public int RecordTransactionForName(int nameId, NameTransactionMessageIdentifier transactionMessage)
        {
            return RecordTransaction(new TransactionInfo(_systemClock(), (int) transactionMessage, nameId));
        }

        public int RecordTransactionFor(Name name, NameTransactionMessageIdentifier transactionMessage)
        {
            return RecordTransaction(new TransactionInfo(_systemClock(), (int) transactionMessage, name));
        }

        public int ExecuteTransactionFor(User user, Name name, NameTransactionMessageIdentifier transactionMessage)
        {
            if (user == null) throw new ArgumentNullException(nameof(user));

            return RecordTransaction(new TransactionInfo(_systemClock(), (int) transactionMessage, name), user);
        }

        OperatorSession EnsureOperatorSession(User user)
        {
            var todaysDate = _systemClock().Date;
            var todaysSession = Queryable.Where<OperatorSession>(_dbContext.Set<OperatorSession>(), s => s.StartDate == todaysDate).ToList();

            var operatorSession = todaysSession.FirstOrDefault(s => s.User.Id == user.Id);
            if (operatorSession != null)
                return operatorSession;

            _contextInfo.EnsureUserContext(user.Id);

            operatorSession = new OperatorSession(
                                                  todaysDate,
                                                  KnownValues.SystemId,
                                                  todaysSession.FirstOrDefault() == null
                                                      ? 1
                                                      : todaysSession.First().SessionId + 1);
            operatorSession.SetUser(user);
            _dbContext.Set<OperatorSession>().Add(operatorSession);
            _dbContext.SaveChanges();

            return operatorSession;
        }

        int RecordTransaction(TransactionInfo transaction, User user = null, int? componentId = null)
        {
            var session = EnsureOperatorSession(user ?? _securityContext.User);

            transaction.SetSession(session);

            _dbContext.Set<TransactionInfo>().Add(transaction);

            _dbContext.SaveChanges();

            _contextInfo.EnsureUserContext(userId: session.User.Id, transactionInfoId: transaction.Id, componentId: componentId);

            return transaction.Id;
        }
    }
}