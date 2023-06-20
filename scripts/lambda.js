exports.handler = async (event, context) => {
  const output = event.records.map((record) => {
    const data = JSON.parse(atob(record.data))

    if (data.city === "seoul")
      data.city = 'k-1'

    if (data.city === 'gyeonggi')
      data.city = 'k-2'

    return {
      recordId: record.recordId,
      result: 'Ok',
      data: btoa(JSON.stringify(data) + '\n')
    }
  })

  return { records: output }
}
