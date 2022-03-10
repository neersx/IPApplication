using System;
using Inprotech.Web.Configuration.Core;
using InprotechKaizen.Model.Policing;

namespace Inprotech.Web.Policing
{
    public static class PolicingRequestItemExtensions
    {
        public static PolicingRequest ToPolicingRequest(this PolicingRequestItem model, DateTime dateEntered)
        {
            return new PolicingRequest(null)
                   {
                       DateEntered = dateEntered,
                       IsSystemGenerated = 0,
                       OnHold = 0
                   }.UpdateFrom(model);
        }
    }

    public static class PolicingRequestExtensions
    {
        public static InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics ToCharacteristics(this PolicingRequest model)
        {
            return new InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics
                   {
                       Action = model.Action,
                       CaseCategory = model.CaseCategory,
                       CaseType = model.CaseType,
                       Jurisdiction = model.Jurisdiction,
                       PropertyType = model.PropertyType,
                       SubType = model.SubType
                   };
        }

        public static PolicingRequest UpdateFrom(this PolicingRequest model, PolicingRequestItem item)
        {
            model.Name = item.Title;
            model.Notes = item.Notes;
            model.FromDate = item.StartDate;
            model.UntilDate = item.EndDate;
            model.LetterDate = item.DateLetters;
            model.NoOfDays = item.ForDays;
            model.IsDueDateOnly = item.DueDateOnly.ToDecimal();
            model.IsReminder = item.Options.Reminders.ToDecimal();
            model.IsLetter = item.Options.Documents.ToDecimal();
            model.IsUpdate = item.Options.Update.ToDecimal();
            model.IsAdhocReminder = item.Options.AdhocReminders.ToDecimal();
            model.IsRecalculateCriteria = item.Options.RecalculateCriteria.ToDecimal();
            model.IsRecalculateReminder = item.Options.RecalculateReminderDates.ToDecimal();
            model.IsRecalculateDueDate = item.Options.RecalculateDueDates.ToDecimal();
            model.IsRecalculateEventDate = item.Options.RecalculateEventDates;
            model.IsEmailFlag = item.Options.EmailReminders;
            model.Jurisdiction = item.Attributes.Jurisdiction?.Code;
            model.ExcludeJurisdiction = Convert.ToDecimal(item.Attributes.ExcludeJurisdiction);
            model.PropertyType = item.Attributes.PropertyType?.Code;
            model.ExcludeProperty = Convert.ToDecimal(item.Attributes.ExcludeProperty);
            model.Irn = item.Attributes.CaseReference?.Code;
            model.CaseType = item.Attributes.CaseType?.Code;
            model.CaseCategory = item.Attributes.CaseCategory?.Code;
            model.SubType = item.Attributes.SubType?.Code;
            model.Office = item.Attributes.Office?.Key.ToString();
            model.Action = item.Attributes.Action?.Code;
            model.ExcludeAction = Convert.ToDecimal(item.Attributes.ExcludeAction);
            model.EventNo = item.Attributes.Event?.Key;
            model.DateOfLaw = item.Attributes.DateOfLaw?.date;
            model.NameType = item.Attributes.NameType?.Code;
            model.NameNo = item.Attributes.Name?.key;

            return model;
        }
    }
}