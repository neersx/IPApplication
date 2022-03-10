using System;
using System.Collections.Generic;
using Inprotech.Contracts;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Components.System.Utilities;

namespace InprotechKaizen.Model.Components.Accounting.Billing.BillReview
{
    public interface IEmailSubjectBodyResolver
    {
        (string Subject, string Body) ResolveForName(int nameId);
        (string Subject, string Body) ResolveForCase(string caseReference);
    }

    public class EmailSubjectBodyResolver : IEmailSubjectBodyResolver
    {
        readonly ILogger<EmailSubjectBodyResolver> _logger;
        readonly ISiteControlReader _siteControlReader;
        readonly IDocItemRunner _docItemRunner;

        readonly Dictionary<int, (string Subject, string Body)> _nameSubjectBodyCache = new();
        readonly Dictionary<string, (string Subject, string Body)> _caseSubjectBodyCache = new();
        
        string _caseSubjectDataItem;
        string _caseBodyDataItem;
        string _nameSubjectDataItem;
        string _nameBodyDataItem;

        bool _settingsLoaded;

        public EmailSubjectBodyResolver(
            ILogger<EmailSubjectBodyResolver> logger,
            ISiteControlReader siteControlReader,
            IDocItemRunner docItemRunner)
        {
            _logger = logger;
            _siteControlReader = siteControlReader;
            _docItemRunner = docItemRunner;
        }

        void PopulateItemConfiguration()
        {
            if (!_settingsLoaded)
            {
                var items = _siteControlReader.ReadMany<string>(SiteControls.EmailCaseSubject,
                                                                SiteControls.EmailCaseBody,
                                                                SiteControls.EmailNameSubject,
                                                                SiteControls.EmailNameBody);

                _caseSubjectDataItem = items[SiteControls.EmailCaseSubject];
                _caseBodyDataItem = items[SiteControls.EmailCaseBody];
                _nameSubjectDataItem = items[SiteControls.EmailNameSubject];
                _nameBodyDataItem = items[SiteControls.EmailNameBody];

                _settingsLoaded = true;
            }
        }
        
        public (string Subject, string Body) ResolveForName(int nameId)
        {
            PopulateItemConfiguration();

            return Resolve(nameId, _nameSubjectDataItem, _nameBodyDataItem, _nameSubjectBodyCache);
        }

        public (string Subject, string Body) ResolveForCase(string caseReference)
        {
            PopulateItemConfiguration();

            return Resolve(caseReference, _caseSubjectDataItem, _caseBodyDataItem, _caseSubjectBodyCache);
        }

        (string Subject, string Body) Resolve<T>(T entryPointValue, string itemNameForSubject, string itemNameForBody, Dictionary<T, (string, string)> cache)
        {
            var subject = string.Empty;
            var body = string.Empty;
            
            if (!cache.TryGetValue(entryPointValue, out var subjectBody))
            {
                if (TryExecuteDocItem(itemNameForSubject, entryPointValue, out var itemSubjectExecutedValue))
                    subject = itemSubjectExecutedValue;

                if (TryExecuteDocItem(itemNameForBody, entryPointValue, out var itemBodyExecutedValue))
                    body = itemBodyExecutedValue;
                
                cache.Add(entryPointValue, (subject, body));
            }
            else
            {
                subject = subjectBody.Item1;
                body = subjectBody.Item2;
            }

            return (subject, body);
        }
        
        bool TryExecuteDocItem<T>(string docItem, T entryPointValue, out string value)
        {
            if (string.IsNullOrWhiteSpace(docItem))
            {
                value = null;
                return false;
            }

            try
            {
                value = _docItemRunner.Run(docItem, new Dictionary<string, object> { { "gstrEntryPoint", entryPointValue } })
                                      .ScalarValueOrDefault<string>();
                return true;
            }
            catch (Exception e)
            {
                _logger.Warning($"Error executing docitem {docItem} with entry point value '{entryPointValue}', using empty value instead. ({e.Message})");
                value = null;
                return false;
            }
        }
    }
}
