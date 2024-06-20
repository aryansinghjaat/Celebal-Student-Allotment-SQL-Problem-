-- Student Allotment SQL Problem

USE student_subject_allotment;
GO


CREATE PROCEDURE spAllocateElectiveSubjects
AS
BEGIN
    DECLARE @student_id VARCHAR(10);
    DECLARE @subject_id VARCHAR(10);
    DECLARE @preference INT;
    DECLARE @available_seats INT;

    DECLARE cur CURSOR FOR
        SELECT sd.StudentId, sp.SubjectId, sp.Preference
        FROM StudentPreference sp
        JOIN StudentDetails sd ON sp.StudentId = sd.StudentId
        ORDER BY sd.GPA DESC, sp.Preference ASC;

    OPEN cur;
    FETCH NEXT FROM cur INTO @student_id, @subject_id, @preference;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Check if the student is already allotted
        IF NOT EXISTS (SELECT 1 FROM Allotments WHERE StudentId = @student_id)
        BEGIN
            SELECT @available_seats = RemainingSeats
            FROM SubjectDetails
            WHERE SubjectId = @subject_id;

            WHILE @preference <= 5 AND @available_seats <= 0
            BEGIN
                FETCH NEXT FROM cur INTO @student_id, @subject_id, @preference;
                IF @@FETCH_STATUS <> 0 BREAK;
                SELECT @available_seats = RemainingSeats
                FROM SubjectDetails
                WHERE SubjectId = @subject_id;
            END

            IF @available_seats > 0
            BEGIN
                INSERT INTO Allotments (SubjectId, StudentId)
                VALUES (@subject_id, @student_id);

                UPDATE SubjectDetails
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = @subject_id;

                -- Delete the remaining preferences for the student
                DELETE FROM StudentPreference
                WHERE StudentId = @student_id AND Preference > @preference;
            END
            ELSE
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM UnallotedStudents WHERE StudentId = @student_id)
                BEGIN
                    INSERT INTO UnallotedStudents (StudentId)
                    VALUES (@student_id);
                END
            END
        END

        FETCH NEXT FROM cur INTO @student_id, @subject_id, @preference;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

-- Execute the procedure
EXEC spAllocateElectiveSubjects;

