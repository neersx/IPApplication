using System;
using System.IO;
using System.Linq;
using System.Text;
using Inprotech.Infrastructure;
using Inprotech.Integration.ExternalApplications.Crm.Request;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.ExternalApplications.Crm
{
    public interface IContactActivityProcessor
    {
        void AddContactActivity(int nameId, ContactActivityRequest request);
    }
    public class ContactActivityProcessor : IContactActivityProcessor
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;
        readonly Func<DateTime> _systemClock;
        readonly ISecurityContext _securityContext;

        public ContactActivityProcessor(IDbContext dbContext, 
            ILastInternalCodeGenerator lastInternalCodeGenerator,
            ISecurityContext securityContext,
            Func<DateTime> systemClock)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            if (lastInternalCodeGenerator == null) throw new ArgumentNullException("lastInternalCodeGenerator");
            if(securityContext == null) throw new ArgumentNullException("securityContext");

            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
            _systemClock = systemClock;
            _securityContext = securityContext;
        }

        public void AddContactActivity(int nameId, ContactActivityRequest request)
        {
            var name = _dbContext.Set<Name>().SingleOrDefault(n => n.Id == nameId);

            if (name == null || !name.NameTypeClassifications.Any(ntc => ntc.NameType.NameTypeCode == KnownNameTypes.Contact && ntc.IsAllowed == 1))
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ContactDoesNotExist.ToString());

            var contactActivity = request.ContactActivity;

            if (contactActivity == null || contactActivity.ActivityType == null || contactActivity.ActivityCategory == null)
                HttpResponseExceptionHelper.RaiseBadRequest(ErrorTypeCode.InvalidParameter.ToString());

            using (var tx = _dbContext.BeginTransaction())
            {
                var activity = Add(name, contactActivity);

                if (request.ContactActivityAttachments != null)
                {
                    var seqNo = 0;
                    foreach (var activityAttachment in request.ContactActivityAttachments)
                    {
                        if (String.IsNullOrEmpty(activityAttachment.FileName) ||
                            String.IsNullOrEmpty(activityAttachment.AttachmentName))
                            HttpResponseExceptionHelper.RaiseBadRequest(ErrorTypeCode.InvalidParameter.ToString());

                        if (!IsValidFileName(activityAttachment.FileName))
                            HttpResponseExceptionHelper.RaiseBadRequest(ErrorTypeCode.NotValidFile.ToString());

                        var attachment = new ActivityAttachment(activity.Id, seqNo++)
                        {
                            AttachmentName = activityAttachment.AttachmentName,
                            FileName = activityAttachment.FileName,
                            PublicFlag = activityAttachment.PublicFlag.HasValue ? activityAttachment.PublicFlag.Value ? 1 : 0 : (decimal?)null
                        };
                        _dbContext.Set<ActivityAttachment>().Add(attachment);
                    }
                }

                _dbContext.SaveChanges();
                tx.Complete();
            }
        }

        Activity Add(Name contactName, ContactActivity contactActivity)
        {
            Name staffName = null;
            Name caller = null;
            Name regardingName = null;
            bool? callType = null;
            short? callSatus = null;

            var activityCategory =
                _dbContext.Set<TableCode>()
                    .FirstOrDefault(
                        tc =>
                            tc.TableTypeId == (int)TableTypes.ContactActivityCategory &&
                            tc.Id == contactActivity.ActivityCategory);
            if(activityCategory == null)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ActivityCategoryDoesntExist.ToString());

            var activityType =
                _dbContext.Set<TableCode>()
                    .FirstOrDefault(
                        tc =>
                            tc.TableTypeId == (int)TableTypes.ContactActivityType &&
                            tc.Id == contactActivity.ActivityType);
            if (activityType == null)
                HttpResponseExceptionHelper.RaiseNotFound(ErrorTypeCode.ActivityTypeDoesntExist.ToString());

            var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().FirstOrDefault(c => c.Id == contactActivity.CaseId);
            if (@case != null && (!@case.PropertyType.CrmOnly.HasValue || !@case.PropertyType.CrmOnly.Value))
                HttpResponseExceptionHelper.RaiseUnauthorized(ErrorTypeCode.NotACrmCase.ToString());

            var outgoingCallTypes = new[] { KnownActivityTypes.PhoneCall, KnownActivityTypes.Correspondence, KnownActivityTypes.Facsimile, KnownActivityTypes.Email };
            if (outgoingCallTypes.Contains(activityType.Id))
            {
                callType = contactActivity.IsOutgoing;
                caller = _dbContext.Set<Name>().FirstOrDefault(nt => nt.Id == contactActivity.CallerId);
                if (activityType.Id == KnownActivityTypes.PhoneCall && contactActivity.IsOutgoing)
                {
                    if (contactActivity.CallStatus != null && KnownCallStatus.GetValues().ContainsKey(contactActivity.CallStatus.Value))
                    {
                        callSatus = contactActivity.CallStatus;
                    }
                    else
                    {
                        callSatus = 1;
                    }
                }
            }

            if (activityType.Id == KnownActivityTypes.ClientRequest)
            {
                contactActivity.Date = _systemClock();
                contactActivity.Incomplete = false;
            }
            else
            {
                staffName = _dbContext.Set<Name>().FirstOrDefault(nt => nt.Id == contactActivity.StaffId) ?? _securityContext.User.Name;
                contactActivity.ClientReference = null;
            }

            if (contactActivity.RegardingId != null && _dbContext.Set<AssociatedName>()
                    .Any(an => an.Id == contactActivity.RegardingId && an.RelatedNameId == contactName.Id
                               && an.Relationship.Equals(KnownRelations.Employs)))
            {
                regardingName = _dbContext.Set<Name>().FirstOrDefault(nt => nt.Id == contactActivity.RegardingId);
            }

            var referredToName = _dbContext.Set<Name>().FirstOrDefault(nt => nt.Id == contactActivity.ReferredToId);

            var longFlag = !String.IsNullOrEmpty(contactActivity.Notes) && contactActivity.Notes.Length > 254;

            if (String.IsNullOrEmpty(contactActivity.Summary))
            {
                contactActivity.Summary = GetDefaultSummary(activityType, callType, contactName, regardingName, @case);
            }

            var activityId = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.Activity);

            if(contactActivity.Summary.Length > 100)
                contactActivity.Summary = contactActivity.Summary.Substring(0, 100);

            if(!String.IsNullOrEmpty(contactActivity.ClientReference) && contactActivity.ClientReference.Length > 50)
                contactActivity.ClientReference = contactActivity.ClientReference.Substring(0, 50);

            if(!String.IsNullOrEmpty(contactActivity.GeneralReference) && contactActivity.GeneralReference.Length > 20)
                contactActivity.GeneralReference = contactActivity.GeneralReference.Substring(0, 20);

            var activity = new Activity(activityId, contactActivity.Summary, activityCategory, activityType, @case, staffName,
                caller, contactName, regardingName, referredToName)
            {
                ActivityDate = contactActivity.Date ?? _systemClock().Date,
                UserIdentityId = _securityContext.User.Id,
                CallType = callType.HasValue ? callType.Value ? 1 : 0 : (decimal?)null,
                CallStatus = callSatus,
                LongFlag = longFlag ? 1 : 0,
                Notes = !longFlag ? contactActivity.Notes : null,
                LongNotes = longFlag ? contactActivity.Notes : null,
                Incomplete = contactActivity.Incomplete ? 1 : 0,
                ClientReference = contactActivity.ClientReference,
                ReferenceNo = contactActivity.GeneralReference
            };

            _dbContext.Set<Activity>().Add(activity);

            return activity;
        }

        static string GetDefaultSummary(TableCode activityType, bool? isOutgoing, Name contactName, Name regardingName, InprotechKaizen.Model.Cases.Case @case)
        {
            var summary = new StringBuilder();
            summary.Append(activityType.Name);
            switch (isOutgoing)
            {
                case true:
                    summary.Append(" - To: ");
                    break;
                case false:
                    summary.Append(" - From: ");
                    break;
                default:
                    summary.Append(" - ");
                    break;
            }
            summary.Append(contactName.FormattedNameOrNull(NameStyles.FirstNameThenFamilyName));
            if (regardingName != null)
            {
                summary.Append(String.Format(" ({0}", regardingName.FormattedNameOrNull()));
                if (!String.IsNullOrEmpty(regardingName.NameCode))
                {
                    summary.Append(" {" + regardingName.NameCode + "}");
                }
                summary.Append(")");
            }
            if (@case != null)
                summary.Append(String.Format(" - Case Ref.: {0}", @case.Irn));

            return summary.ToString();
        }

        static bool IsValidFileName(string filePath)
        {
            var path = Path.GetDirectoryName(filePath);
            var fileName = Path.GetFileName(filePath);

            var validPath = !String.IsNullOrEmpty(path) &&
                            path.IndexOfAny(Path.GetInvalidPathChars()) < 0;
            var validFileName = !String.IsNullOrEmpty(fileName) &&
                                fileName.IndexOfAny(Path.GetInvalidFileNameChars()) < 0;

            return validPath && validFileName;
        }
    }
}
