namespace InprotechKaizen.Model.Components.Names
{
    public class NewNameTeleCommunication
    {
        public string TelecomNotes { get; set; }

        public bool Owner { get; set; }

        public int TelecomTypeKey { get; set; }

        public string Isd { get; set; }

        public string AreaCode { get; set; }

        public string TelecomNumber { get; set; }

        public string Extension { get; set; }

        public int? CarrierKey { get; set; }

        public bool? ReminderAddress { get; set; }

        public bool IsMainTelecom { get; set; }
    }
}
