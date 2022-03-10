namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public class DiaryKeyDetails
    {
        public DiaryKeyDetails(int empNo, int entryNo)
        {
            EmployeeNo = empNo;
            EntryNo = entryNo;
        }

        public int EmployeeNo { get; set; }

        public int EntryNo { get; set; }
    }
}