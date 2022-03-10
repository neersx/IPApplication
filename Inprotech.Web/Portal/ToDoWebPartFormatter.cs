using System;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Legacy;

namespace Inprotech.Web.Portal
{
    [WebPartFormatterConfiguration("/CPAInproma/Desktop/ModulePages/Dates/ToDo/Internal/ToDoRequest.ashx", "portal/widgets/to-do-list.html")]
    public class ToDoWebPartFormatter : IWebPartFormatter
    {
        public object Load(XElement xml)
        {
            return (from e in xml.Elements("xmldata")
                   from d in e.Elements(Xmlns.DataSet + "diffgram")
                   from s in d.Elements(Xmlns.Cpa + "NewDataSet")
                   from t in s.Elements(Xmlns.Cpa + "MainTable")
                   select new
                          {
                              CaseRef = (string)t.Element(Xmlns.Cpa + "CaseReference"),
                              AdHocRef = (string)t.Element(Xmlns.Cpa + "AlertReference"),
                              DueDate = (DateTime?)t.Element(Xmlns.Cpa + "DueDate"),
                              ReminderDate = (DateTime?)t.Element(Xmlns.Cpa + "ReminderDate"),
                              MessageText = (string)t.Element(Xmlns.Cpa + "Message"),
                              IsAdHoc = (bool?)t.Element(Xmlns.Cpa + "IsAdHocReminder"),
                              Owner = (string)t.Element(Xmlns.Cpa + "Owner"),
                              EventName = (string)t.Element(Xmlns.Cpa + "EventDescription"),
                              ReminderAdded = (DateTime?)t.Element(Xmlns.Cpa + "ReminderDate"),
                              HoldUntil = (DateTime?)t.Element(Xmlns.Cpa + "HoldUntil"),
                              CaseType = (string)t.Element(Xmlns.Cpa + "CaseTypeDescription"),
                              PropertyType = (string)t.Element(Xmlns.Cpa + "PropertyTypeDescription"),
                              StaffMember = (string)t.Element(Xmlns.Cpa + "StaffMember"),
                              Signatory = (string)t.Element(Xmlns.Cpa + "SignatoryName"),
                              NextReminder = (DateTime?)t.Element(Xmlns.Cpa + "NextReminderDate")
                          }).Take(25);
        }
    }
}